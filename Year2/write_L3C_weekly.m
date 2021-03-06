clear all;
close all;

fileversion='1.0';
fillvalu=-9999;
days19700101=datenum(1970,1,1,0,0,0);

load('/net/nfs/home/chakroun/CCI_SSS/Level2/aux_files/latlon_ease.mat') %fichier grille
load ('/net/nfs/home/chakroun/CCI_SSS/Level2/aux_files/lsc_flag_ease.mat') %fichier flag lsc

nlon=length(lon_ease);
nlat=length(lat_ease);

%chemin des input (produits corriges latitudinalement et de la SST)

input_dir_smos='/net/nfs/tmp15/chakroun/L3_output/Level3_intermediate/SSS_SMOS_merged/weekly/';%input directory
dirL3_smos=dir(input_dir_smos);
input_dir_smap='/net/nfs/tmp15/chakroun/L3_output/Level3_intermediate/SSS_SMAP_merged/weekly/';%input directory
dirL3_smap=dir(input_dir_smap);
input_dir_aquarius='/net/nfs/tmp15/chakroun/L3_output/Level3_intermediate/SSS_AQUARIUS_merged/weekly/';%input directory
dirL3_aquarius=dir(input_dir_aquarius);

%chemin output

output_dir='/net/nfs/tmp15/chakroun/L3_output/L3C_nc/weekly/';%output directory

%on cree toutes les dates qu'on va parcourir

YYYY0=str2num(dirL3_smos(4).name(end-18:end-15));
MM0=str2num(dirL3_smos(4).name(end-14:end-13));
jour0=str2num(dirL3_smos(4).name(end-12:end-11));
n0=datenum(YYYY0,MM0,jour0);

YYYYend=str2num(dirL3_smos(end).name(end-18:end-15));
MMend=str2num(dirL3_smos(end).name(end-14:end-13));
jourend=str2num(dirL3_smos(end).name(end-12:end-11));
nend=datenum(YYYYend,MMend,jourend);

njours=nend-n0;

for kk=1:njours

	date=datestr(kk+n0-1,30);
	date_file=date(1:8);

	YYYYtime=str2num(date_file(1:4));
	MMtime=str2num(date_file(5:6));
	JJtime=str2num(date_file(7:8));
	date_time=datenum(YYYYtime,MMtime,JJtime,0,0,0);

	%initialisation

	SSS_smos=nan(nlon,nlat);
	SSS_smap=nan(nlon,nlat);
	SSS_aquarius=nan(nlon,nlat);

	SSS_smos_bias=nan(nlon,nlat);
	SSS_smap_bias=nan(nlon,nlat);
	SSS_aquarius_bias=nan(nlon,nlat);	

	SSS_smos_random=nan(nlon,nlat);
	SSS_smap_random=nan(nlon,nlat);
	SSS_aquarius_random=nan(nlon,nlat);	

	nobs_smos=nan(nlon,nlat);
	nobs_smap=nan(nlon,nlat);
	nobs_aquarius=nan(nlon,nlat);

	sss_qc_smos=nan(nlon,nlat);
	sss_qc_smap=nan(nlon,nlat);
	sss_qc_aquarius=nan(nlon,nlat);

	%lecture des donnees

	input_smos_file=([input_dir_smos,'smosL3_weeklyaveraged_',date_file,'centred.mat'])
	input_smap_file=([input_dir_smap,'smapL3_weeklyaveraged_',date_file,'centred.mat'])
	input_aquarius_file=([input_dir_aquarius,'aquariusL3_weeklyaveraged_',date_file,'centred.mat'])

	if exist(input_smos_file)
		load(input_smos_file);
	end
	if exist(input_smap_file)
		load(input_smap_file);
	end
	if exist(input_aquarius_file)
		load(input_aquarius_file);
	end

	%inverser dimension des matrices

	for ilon=1:nlon
		for ilat=1:ilat
			SSS_smos_inv(ilat,ilon)=SSS_smos(ilon,ilat);
			SSS_smap_inv(ilat,ilon)=SSS_smap(ilon,ilat);
			SSS_aquarius_inv(ilat,ilon)=SSS_aquarius(ilon,ilat);

			SSS_smos_bias_inv(ilat,ilon)=SSS_smos_bias(ilon,ilat);
			SSS_smap_bias_inv(ilat,ilon)=SSS_smap_bias(ilon,ilat);
			SSS_aquarius_bias_inv(ilat,ilon)=SSS_aquarius_bias(ilon,ilat);

			SSS_smos_random_inv(ilat,ilon)=SSS_smos_random(ilon,ilat);
			SSS_smap_random_inv(ilat,ilon)=SSS_smap_random(ilon,ilat);
			SSS_aquarius_random_inv(ilat,ilon)=SSS_aquarius_random(ilon,ilat);

			nobs_smos_inv(ilat,ilon)=nobs_smos(ilon,ilat);
			nobs_smap_inv(ilat,ilon)=nobs_smap(ilon,ilat);
			nobs_aquarius_inv(ilat,ilon)=nobs_aqurius(ilon,ilat);

			sss_qc_smos_inv(ilat,ilon)=sss_qc_smos(ilon,ilat);
			sss_qc_smap_inv(ilat,ilon)=sss_qc_smap(ilon,ilat);
			sss_qc_aquarius_inv(ilat,ilon)=sss_qc_aqurius(ilon,ilat);
		end
	end

	%time definition

	date_start=datestr(kk+n0-4,30);
	date_end=datestr(kk+n0+3,30);

	time_duration=7;

	%ice flag

	isc_flag=zeros(nlon,nlat,1);

	%ecriture des donnees

	L3C_ncfile=([output_dir,'ESACCI-SEASURFACESALINITY-L3C-SSS-SMOSSMAPAQUARIUS_7Day_runningmean_Daily_25km-',date_file,'-fv',fileversion,'.nc']);%output file
	nc=netcdf.create(L3C_ncfile,'netcdf4');

        %%%%%%%%%%%%%%%%%%%%%%%

	%dimensions

	dimidX = netcdf.defDim(nc,'time',1);
	dimidY = netcdf.defDim(nc,'lon',length(lon_ease));
	dimidZ = netcdf.defDim(nc,'lat',length(lat_ease));

	%%time  mettre a jour

	%%global attributes

	NC_GLOBAL = netcdf.getConstant('NC_GLOBAL');

        netcdf.putAtt(nc,NC_GLOBAL,'creation_time',datestr(now));
        
        Value= 'ACRI-ST; LOCEAN' ;
        netcdf.putAtt(nc,NC_GLOBAL,'institution',Value);
        
        Value =  'CF-1.7';
        netcdf.putAtt(nc,NC_GLOBAL,'Conventions',Value);
        
        Value =  'Ocean, Ocean Salinity, Sea Surface Salinity, Satellite';
        netcdf.putAtt(nc,NC_GLOBAL,'keywords',Value);

        Value =  'European Space Agency - ESA Climate Office';
        netcdf.putAtt(nc,NC_GLOBAL,'naming_authority',Value);

        Value =  'NASA Global Change Master Directory (GCMD) SCience Keywords';
        netcdf.putAtt(nc,NC_GLOBAL,'keywords_vocabulary',Value);
        
        Value =  'Grid';
        netcdf.putAtt(nc,NC_GLOBAL,'cdm_data_type',Value);
        
        Value= 'ACRI-ST; LOCEAN';
        netcdf.putAtt(nc,NC_GLOBAL,'creator_name',Value);
        
        Value= 'http://cci.esa.int/salinity';
        netcdf.putAtt(nc,NC_GLOBAL,'creator_url',Value);
        
        Value= 'Climate Change Initiative - European Space Agency';
        netcdf.putAtt(nc,NC_GLOBAL,'project',Value);
        
        Value= 'ESA CCI Data Policy: free and open access';%tocheck
        netcdf.putAtt(nc,NC_GLOBAL,'license',Value);
        
        Value= 'NetCDF Climate and Forecast (CF) Metadata Convention version 1.7';
        netcdf.putAtt(nc,NC_GLOBAL,'standard_name_vocabulary',Value);

        Value= 'PROTEUS; SAC-D; SMAP'; 
        netcdf.putAtt(nc,NC_GLOBAL,'platform',Value);

        Value= 'SMOS/MIRAS; Aquarius; SMAP';
        netcdf.putAtt(nc,NC_GLOBAL,'sensor',Value);
        
        Value= '50km';
        netcdf.putAtt(nc,NC_GLOBAL,'spatial_resolution',Value);
        
        Value= 'degrees_north';
        netcdf.putAtt(nc,NC_GLOBAL,'geospatial_lat_units',Value);
        
        Value= 'degrees_east';
        netcdf.putAtt(nc,NC_GLOBAL,'geospatial_lon_units',Value);
        
        Value= ' ';
        netcdf.putAtt(nc,NC_GLOBAL,'date_modified',Value);
        
        UUID = java.util.UUID.randomUUID;
        Value= char(UUID);
        netcdf.putAtt(nc,NC_GLOBAL,'tracking_id',Value); 

        Value= 'meriem.chakroun@acri-st.fr';%tocheck
        netcdf.putAtt(nc,NC_GLOBAL,'creator_email',Value);

        Value =  time_duration; %(?)
        netcdf.putAtt(nc,NC_GLOBAL,'time_coverage_duration',Value);
        
        Value= -90.0;
        netcdf.putAtt(nc,NC_GLOBAL,'geospatial_lat_min',Value);
        
        Value= 90.0;
        netcdf.putAtt(nc,NC_GLOBAL,'geospatial_lat_max',Value);
        
        Value= -180.0;
        netcdf.putAtt(nc,NC_GLOBAL,'geospatial_lon_min',Value);
        
        Value= 180.0;
        netcdf.putAtt(nc,NC_GLOBAL,'geospatial_lon_max',Value);

        Value= datestr(now,30);
        netcdf.putAtt(nc,NC_GLOBAL,'date_created',Value);

        Value= date_start;
        netcdf.putAtt(nc,NC_GLOBAL,'time_coverage_start',Value);

        Value= 'ESA CCI Sea Surface Salinity ECV Product';
	netcdf.putAtt(nc,NC_GLOBAL,'title',Value)

        Value= ['SMOS ESAL2OSv622/CATDS RE05, SMAP L2Cv4/RSS, Aquarius L3 v5.0'];%tocheck        
        netcdf.putAtt(nc,NC_GLOBAL,'source',Value);
        
        Value= 'http://cci.esa.int/salinity';
        netcdf.putAtt(nc,NC_GLOBAL,'references',Value);

        
        Value= 'Weekly Sea Surface Salinity L3 data from SMOS, SMAP and Aquarius'; %tocheck
        netcdf.putAtt(nc,NC_GLOBAL,'comment',Value);   

        Value = '1.0' ;
        netcdf.putAtt(nc,NC_GLOBAL,'product_version',Value);  
         
        [path,fname,extension]=fileparts(L3C_ncfile);       
        Value= [fname extension];
        netcdf.putAtt(nc,NC_GLOBAL,'id',Value);
       
        Value= 'P7D';
        netcdf.putAtt(nc,NC_GLOBAL,'time_coverage_resolution',Value);

        Value =  fileversion;
        netcdf.putAtt(nc,NC_GLOBAL,'product_version',Value);
                  
        Value= single(0.25);
        netcdf.putAtt(nc,NC_GLOBAL,'geospatial_lat_resolution',Value);
        
        Value= single(0.25);
        netcdf.putAtt(nc,NC_GLOBAL,'geospatial_lon_resolution',Value);
       
        Value= '25km EASE 2 grid';
        netcdf.putAtt(nc,NC_GLOBAL,'spatial_grid',Value);

        Value= single(0);
        netcdf.putAtt(nc,NC_GLOBAL,'geospatial_vertical_min',Value);
        
        Value= single(0);
        netcdf.putAtt(nc,NC_GLOBAL,'geospatial_vertical_max',Value);
        
        Value =  'ESA CCI Sea Surface Salinity';
        netcdf.putAtt(nc,NC_GLOBAL,'summary',Value);
        
        Value =  date_end ;
        netcdf.putAtt(nc,NC_GLOBAL,'time_coverage_end',Value);
        
        Value =  ' ';
        netcdf.putAtt(nc,NC_GLOBAL,'history',Value);
            
	%%%%%%variables%%%%%%%

	varid=netcdf.defVar(nc,'time','float',[dimidX]);
	netcdf.putAtt(nc,varid,'long_name','time');
	netcdf.putAtt(nc,varid,'units','days since 1970-01-01 00:00:00 UTC');
	netcdf.putAtt(nc,varid,'standard_name','time');
	netcdf.putAtt(nc,varid,'calendar','standard');
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,date_time-days19700101);

	varid=netcdf.defVar(nc,'lon','float',[dimidY]);
	netcdf.putAtt(nc,varid,'long_name','longitude');
	netcdf.putAtt(nc,varid,'units','degrees_east');
	netcdf.putAtt(nc,varid,'standard_name','longitude');
	netcdf.putAtt(nc,varid,'valid_min', single(-180));
	netcdf.putAtt(nc,varid,'valid_max', single(180));
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,lon_ease);

	varid=netcdf.defVar(nc,'lat','float',[dimidZ]);
	netcdf.putAtt(nc,varid,'long_name','latitude');
	netcdf.putAtt(nc,varid,'units','degrees_north');
	netcdf.putAtt(nc,varid,'standard_name','latitude');
	netcdf.putAtt(nc,varid,'valid_min',single(-90));
	netcdf.putAtt(nc,varid,'valid_max',single(90));
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,lat_ease);


	varid=netcdf.defVar(nc,'sss_smos','float',[dimidX dimidY dimidZ]);
	netcdf.putAtt(nc,varid,'long_name','Unbiased Sea Surface Salinity');
	%netcdf.putAtt(nc,varid,'units','');
	netcdf.putAtt(nc,varid,'standard_name','sea_surface_salinity');
	netcdf.putAtt(nc,varid,'valid_min',single(0));
	netcdf.putAtt(nc,varid,'valid_max',single(50));
	%netcdf.putAtt(nc,varid,'scale_factor',1);
	%netcdf.putAtt(nc,varid,'add_offset',0);
	netcdf.defVarFill(nc,varid,false,NaN);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,SSS_smos_inv);

	varid=netcdf.defVar(nc,'sss_smap','float',[dimidX dimidY dimidZ]);
	netcdf.putAtt(nc,varid,'long_name','Unbiased Sea Surface Salinity');
	%netcdf.putAtt(nc,varid,'units','');
	netcdf.putAtt(nc,varid,'standard_name','sea_surface_salinity');
	netcdf.putAtt(nc,varid,'valid_min',single(0));
	netcdf.putAtt(nc,varid,'valid_max',single(50));
	%netcdf.putAtt(nc,varid,'scale_factor',1);
	%netcdf.putAtt(nc,varid,'add_offset',0);
	netcdf.defVarFill(nc,varid,false,NaN);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,SSS_smap_inv);   

	varid=netcdf.defVar(nc,'sss_aquarius','float',[dimidX dimidY dimidZ]);
	netcdf.putAtt(nc,varid,'long_name','Unbiased Sea Surface Salinity');
	%netcdf.putAtt(nc,varid,'units','');
	netcdf.putAtt(nc,varid,'standard_name','sea_surface_salinity');
	netcdf.putAtt(nc,varid,'valid_min',single(0));
	netcdf.putAtt(nc,varid,'valid_max',single(50));
	%netcdf.putAtt(nc,varid,'scale_factor',1);
	%netcdf.putAtt(nc,varid,'add_offset',0);
	netcdf.defVarFill(nc,varid,false,NaN);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,SSS_aquarius_inv);   

	varid=netcdf.defVar(nc,'sss_smos_random_error','float',[dimidX dimidY dimidZ]);     
        netcdf.putAtt(nc,varid,'long_name','Sea Surface Salinity Random Error');
        %netcdf.putAtt(nc,varid,'units','');
        %netcdf.putAtt(nc,varid,'standard_name','sea_surface_salinity_random_error');
        netcdf.putAtt(nc,varid,'valid_min',single(0));
        netcdf.putAtt(nc,varid,'valid_max',single(100));
        %netcdf.putAtt(nc,varid,'scale_factor',1);
        %netcdf.putAtt(nc,varid,'add_offset',0);
	netcdf.defVarFill(nc,varid,false,NaN);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,SSS_smos_random_inv);

	varid=netcdf.defVar(nc,'sss_smap_random_error','float',[dimidX dimidY dimidZ]);     
        netcdf.putAtt(nc,varid,'long_name','Sea Surface Salinity Random Error');
        %netcdf.putAtt(nc,varid,'units','');
        %netcdf.putAtt(nc,varid,'standard_name','sea_surface_salinity_random_error');
        netcdf.putAtt(nc,varid,'valid_min',single(0));
        netcdf.putAtt(nc,varid,'valid_max',single(100));
        %netcdf.putAtt(nc,varid,'scale_factor',1);
        %netcdf.putAtt(nc,varid,'add_offset',0);
	netcdf.defVarFill(nc,varid,false,NaN);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,SSS_smap_random_inv);

 	varid=netcdf.defVar(nc,'sss_aquarius_random_error','float',[dimidX dimidY dimidZ]);     
        netcdf.putAtt(nc,varid,'long_name','Sea Surface Salinity Random Error');
        %netcdf.putAtt(nc,varid,'units','');
        %netcdf.putAtt(nc,varid,'standard_name','sea_surface_salinity_random_error');
        netcdf.putAtt(nc,varid,'valid_min',single(0));
        netcdf.putAtt(nc,varid,'valid_max',single(100));
        %netcdf.putAtt(nc,varid,'scale_factor',1);
        %netcdf.putAtt(nc,varid,'add_offset',0);
	netcdf.defVarFill(nc,varid,false,NaN);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,SSS_aquarius_random_inv);

	varid=netcdf.defVar(nc,'sss_smos_bias','float',[dimidX dimidY dimidZ]);  
        netcdf.putAtt(nc,varid,'long_name','Bias in Sea Surface Salinity');
        %netcdf.putAtt(nc,varid,'units','pss');
        %netcdf.putAtt(nc,varid,'standard_name','sea_surface_salinity_bias');
        netcdf.putAtt(nc,varid,'valid_min',single(-100));
        netcdf.putAtt(nc,varid,'valid_max',single(100));
        %netcdf.putAtt(nc,varid,'scale_factor',1);
        %netcdf.putAtt(nc,varid,'add_offset',0);
        netcdf.defVarFill(nc,varid,false,NaN);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,SSS_smos_bias_inv);

	varid=netcdf.defVar(nc,'sss_smap_bias','float',[dimidX dimidY dimidZ]);  
        netcdf.putAtt(nc,varid,'long_name','Bias in Sea Surface Salinity');
        %netcdf.putAtt(nc,varid,'units','pss');
        %netcdf.putAtt(nc,varid,'standard_name','sea_surface_salinity_bias');
        netcdf.putAtt(nc,varid,'valid_min',single(-100));
        netcdf.putAtt(nc,varid,'valid_max',single(100));
        %netcdf.putAtt(nc,varid,'scale_factor',1);
        %netcdf.putAtt(nc,varid,'add_offset',0);
        netcdf.defVarFill(nc,varid,false,NaN);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,SSS_smap_bias_inv);

	varid=netcdf.defVar(nc,'sss_aquarius_bias','float',[dimidX dimidY dimidZ]);  
        netcdf.putAtt(nc,varid,'long_name','Bias in Sea Surface Salinity');
        %netcdf.putAtt(nc,varid,'units','pss');
        %netcdf.putAtt(nc,varid,'standard_name','sea_surface_salinity_bias');
        netcdf.putAtt(nc,varid,'valid_min',single(-100));
        netcdf.putAtt(nc,varid,'valid_max',single(100));
        %netcdf.putAtt(nc,varid,'scale_factor',1);
        %netcdf.putAtt(nc,varid,'add_offset',0);
        netcdf.defVarFill(nc,varid,false,NaN);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,SSS_aquarius_bias_inv);

	varid=netcdf.defVar(nc,'sss_qc_smos','short',[dimidX dimidY dimidZ]);  
        netcdf.putAtt(nc,varid,'long_name','Sea Surface Salinity Quality Check, 0=Good; 1=Bad');
        %netcdf.putAtt(nc,varid,'units','');
        %netcdf.putAtt(nc,varid,'standard_name','SSS global quality flag');
        netcdf.putAtt(nc,varid,'valid_min',int16(0));
        netcdf.putAtt(nc,varid,'valid_max',int16(1));
        netcdf.defVarFill(nc,varid,false,999);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,int16(sss_qc_smos));  %a mettre a jour

	varid=netcdf.defVar(nc,'sss_qc_smap','short',[dimidX dimidY dimidZ]);  
        netcdf.putAtt(nc,varid,'long_name','Sea Surface Salinity Quality Check, 0=Good; 1=Bad');
        %netcdf.putAtt(nc,varid,'units','');
        %netcdf.putAtt(nc,varid,'standard_name','SSS global quality flag');
        netcdf.putAtt(nc,varid,'valid_min',int16(0));
        netcdf.putAtt(nc,varid,'valid_max',int16(1));
        netcdf.defVarFill(nc,varid,false,999);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,int16(sss_qc_smap));  %a mettre a jour

	varid=netcdf.defVar(nc,'sss_qc_aquarius','short',[dimidX dimidY dimidZ]);  
        netcdf.putAtt(nc,varid,'long_name','Sea Surface Salinity Quality Check, 0=Good; 1=Bad');
        %netcdf.putAtt(nc,varid,'units','');
        %netcdf.putAtt(nc,varid,'standard_name','SSS global quality flag');
        netcdf.putAtt(nc,varid,'valid_min',int16(0));
        netcdf.putAtt(nc,varid,'valid_max',int16(1));
        netcdf.defVarFill(nc,varid,false,999);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,int16(sss_qc_aquarius));  %a mettre a jour

	varid=netcdf.defVar(nc,'Total_nobs_smos','short',[dimidX dimidY dimidZ]);  
	netcdf.putAtt(nc,varid,'long_name','Number of SMOS observations after filtering');
	%netcdf.putAtt(nc,varid,'units','');
	%netcdf.putAtt(nc,varid,'standard_name','Land sea contamination flag');
	netcdf.putAtt(nc,varid,'valid_min',int16(0));
	netcdf.putAtt(nc,varid,'valid_max',int16(100));
	netcdf.defVarFill(nc,varid,false,999);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,int16(nobs_smos));  %a mettre a jour

	varid=netcdf.defVar(nc,'Total_nobs_smap','short',[dimidX dimidY dimidZ]);  
	netcdf.putAtt(nc,varid,'long_name','Number of SMAP observations after filtering');
	%netcdf.putAtt(nc,varid,'units','');
	%netcdf.putAtt(nc,varid,'standard_name','Ice sea contamination flag');
	netcdf.putAtt(nc,varid,'valid_min',int16(0));
	netcdf.putAtt(nc,varid,'valid_max',int16(100));
	netcdf.defVarFill(nc,varid,false,999);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,int16(nobs_smap));  %a mettre a jour

	varid=netcdf.defVar(nc,'Total_nobs_aquarius','short',[dimidX dimidY dimidZ]);  
	netcdf.putAtt(nc,varid,'long_name','Number of AQUARIUS observations after filtering');
	%netcdf.putAtt(nc,varid,'units','');
	%netcdf.putAtt(nc,varid,'standard_name','Ice sea contamination flag');
	netcdf.putAtt(nc,varid,'valid_min',int16(0));
	netcdf.putAtt(nc,varid,'valid_max',int16(100));
	netcdf.defVarFill(nc,varid,false,999);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,int16(nobs_aquarius));  %a mettre a jour

	varid=netcdf.defVar(nc,'Noutliers_L4_smos','short',[dimidX dimidY dimidZ]);  
	netcdf.putAtt(nc,varid,'long_name','Number of SMOS observations rejected in level 4');
	%netcdf.putAtt(nc,varid,'units','');
	%netcdf.putAtt(nc,varid,'standard_name','Land sea contamination flag');
	netcdf.putAtt(nc,varid,'valid_min',int16(0));
	netcdf.putAtt(nc,varid,'valid_max',int16(100));
	netcdf.defVarFill(nc,varid,false,999);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,int16(noutliers_L4_smos));  %a mettre a jour

	varid=netcdf.defVar(nc,'Noutliers_L4_smap','short',[dimidX dimidY dimidZ]);  
	netcdf.putAtt(nc,varid,'long_name','Number of SMAP observations rejected in level 4');
	%netcdf.putAtt(nc,varid,'units','');
	%netcdf.putAtt(nc,varid,'standard_name','Ice sea contamination flag');
	netcdf.putAtt(nc,varid,'valid_min',int16(0));
	netcdf.putAtt(nc,varid,'valid_max',int16(100));
	netcdf.defVarFill(nc,varid,false,999);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,int16(noutliers_L4_smap));  %a mettre a jour

	varid=netcdf.defVar(nc,'Noutliers_L4_aquarius','short',[dimidX dimidY dimidZ]);  
	netcdf.putAtt(nc,varid,'long_name','Number of AQUARIUS observations rejected in level 4');
	%netcdf.putAtt(nc,varid,'units','');
	%netcdf.putAtt(nc,varid,'standard_name','Ice sea contamination flag');
	netcdf.putAtt(nc,varid,'valid_min',int16(0));
	netcdf.putAtt(nc,varid,'valid_max',int16(100));
	netcdf.defVarFill(nc,varid,false,999);
	netcdf.defVarDeflate(nc,varid,false,true,6);
	netcdf.putVar(nc,varid,int16(noutliers_L4_aquarius));  %a mettre a jour


	netcdf.close(nc)
end
